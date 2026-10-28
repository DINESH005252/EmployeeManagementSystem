package listener;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import service.AttendanceService;
import service.AuthService;
import service.EmployeeService;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Runs once when Tomcat starts the app:
 *  1) creates the default HR account.
 *  2) immediately closes any open attendance record left over from a previous day
 *     (catch-up, in case Tomcat was off at the scheduled time).
 *  3) starts a daily background job that auto-checks-out anyone who forgot to check out today.
 */
@WebListener
public class AppInitListener implements ServletContextListener {

    /** The daily job runs at this time and uses it as the check-out time for today's open records. */
    private static final LocalTime AUTO_CHECKOUT_TIME = LocalTime.of(18, 30);

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent event) {
        try {
            new AuthService(new EmployeeService()).seedDefaultUsers();
            event.getServletContext().log("Default login accounts are ready.");
        } catch (RuntimeException ex) {
            event.getServletContext().log("Could not create default users: " + ex.getMessage(), ex);
        }

        AttendanceService attendanceService = new AttendanceService(new EmployeeService());

        try {
            int closed = attendanceService.autoCheckOutStaleRecords(LocalDate.now());
            event.getServletContext().log("Startup catch-up: auto-closed " + closed
                    + " stale open record(s) from previous day(s).");
        } catch (RuntimeException ex) {
            event.getServletContext().log("Startup catch-up failed: " + ex.getMessage(), ex);
        }

        startAutoCheckoutScheduler(event, attendanceService);
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        if (scheduler != null) scheduler.shutdownNow();
    }

    private void startAutoCheckoutScheduler(ServletContextEvent event, AttendanceService attendanceService) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "auto-checkout-scheduler");
            t.setDaemon(true);
            return t;
        });

        Runnable job = () -> {
            try {
                int closed = attendanceService.autoCheckOutOpenRecords(LocalDate.now(), AUTO_CHECKOUT_TIME);
                event.getServletContext().log("Auto-checkout job ran: " + closed + " record(s) closed.");
            } catch (RuntimeException ex) {
                event.getServletContext().log("Auto-checkout job failed: " + ex.getMessage(), ex);
            }
        };

        long initialDelay = millisUntil(AUTO_CHECKOUT_TIME);
        long oneDay = TimeUnit.DAYS.toMillis(1);
        scheduler.scheduleAtFixedRate(job, initialDelay, oneDay, TimeUnit.MILLISECONDS);
        event.getServletContext().log("Auto-checkout scheduled daily at " + AUTO_CHECKOUT_TIME
                + " (first run in " + (initialDelay / 60000) + " minute(s)).");
    }

    /** Milliseconds from now until the next occurrence of the given time today or tomorrow. */
    private static long millisUntil(LocalTime target) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime next = now.toLocalDate().atTime(target);
        if (!next.isAfter(now)) next = next.plusDays(1);
        return Duration.between(now, next).toMillis();
    }
}
package com.smartoffice.util;

import java.io.InputStream;
import java.time.DayOfWeek;
import java.util.*;

public class PayrollRules {
    private static final String DEFAULT_COMPANY = "SmartOffice Technologies Pvt. Ltd.";
    private static final Set<DayOfWeek> DEFAULT_WEEKLY_OFF = EnumSet.of(DayOfWeek.SUNDAY);
    private static final String DEFAULT_LOP_BASIS = "BASIC";
    private static final double DEFAULT_HALFDAY_FRACTION = 0.5;
    private static final Set<String> DEFAULT_UNPAID_LEAVES = new HashSet<>(Arrays.asList("UNPAID", "LOP"));
    private static final String DEFAULT_UNMARKED_POLICY = "UNPAID";

    private static Set<DayOfWeek> weeklyOffs = DEFAULT_WEEKLY_OFF;
    private static String lopBasis = DEFAULT_LOP_BASIS;
    private static double halfDayUnpaidFraction = DEFAULT_HALFDAY_FRACTION;
    private static Set<String> unpaidLeaveTypes = DEFAULT_UNPAID_LEAVES;
    private static String unmarkedDaysPolicy = DEFAULT_UNMARKED_POLICY;
    private static String companyName = DEFAULT_COMPANY;

    static {
        loadRules();
    }

    public static synchronized void loadRules() {
        try (InputStream in = PayrollRules.class.getClassLoader().getResourceAsStream("payroll-rules.properties")) {
            if (in != null) {
                Properties p = new Properties();
                p.load(in);

                String wOff = p.getProperty("weekly.off");
                if (wOff != null && !wOff.trim().isEmpty()) {
                    Set<DayOfWeek> days = EnumSet.noneOf(DayOfWeek.class);
                    for (String d : wOff.split(",")) {
                        try {
                            days.add(DayOfWeek.valueOf(d.trim().toUpperCase()));
                        } catch (Exception ignored) {}
                    }
                    if (!days.isEmpty()) {
                        weeklyOffs = Collections.unmodifiableSet(days);
                    }
                }

                String lb = p.getProperty("lop.basis");
                if ("GROSS".equalsIgnoreCase(lb)) {
                    lopBasis = "GROSS";
                } else {
                    lopBasis = "BASIC";
                }

                String hf = p.getProperty("halfday.unpaid.fraction");
                if (hf != null) {
                    try {
                        halfDayUnpaidFraction = Double.parseDouble(hf.trim());
                    } catch (Exception ignored) {}
                }

                String ult = p.getProperty("unpaid.leave.types");
                if (ult != null && !ult.trim().isEmpty()) {
                    Set<String> set = new HashSet<>();
                    for (String t : ult.split(",")) {
                        if (!t.trim().isEmpty()) set.add(t.trim().toUpperCase());
                    }
                    unpaidLeaveTypes = Collections.unmodifiableSet(set);
                }

                String ump = p.getProperty("unmarked.days.policy");
                if ("PAID".equalsIgnoreCase(ump)) {
                    unmarkedDaysPolicy = "PAID";
                } else {
                    unmarkedDaysPolicy = "UNPAID";
                }

                String cn = p.getProperty("company.name");
                if (cn != null && !cn.trim().isEmpty()) {
                    companyName = cn.trim();
                }
            }
        } catch (Exception e) {
            // Keep safe defaults
        }
    }

    public static Set<DayOfWeek> getWeeklyOffs() { return weeklyOffs; }
    public static Set<DayOfWeek> getWeeklyOffDays() { return weeklyOffs; }
    public static String getLopBasis() { return lopBasis; }
    public static double getHalfDayUnpaidFraction() { return halfDayUnpaidFraction; }
    public static double getHalfDayDeductionFraction() { return halfDayUnpaidFraction; }
    public static Set<String> getUnpaidLeaveTypes() { return unpaidLeaveTypes; }
    public static String getUnmarkedDaysPolicy() { return unmarkedDaysPolicy; }
    public static String getUnmarkedPolicy() { return unmarkedDaysPolicy; }
    public static String getCompanyName() { return companyName; }
}

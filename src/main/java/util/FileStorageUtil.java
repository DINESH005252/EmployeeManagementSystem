package util;

import jakarta.servlet.ServletContext;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.Part;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

public class FileStorageUtil {

    private static final String UPLOAD_SUBDIR = "uploads" + File.separator + "tasks";
    public static final long DEFAULT_MAX_TOTAL_BYTES = 25L * 1024 * 1024; // 25 MB max total limit

    /**
     * Resolves the upload directory on disk, ensuring it exists.
     */
    public static File getUploadDirectory(ServletContext ctx) {
        String realPath = ctx.getRealPath("/" + UPLOAD_SUBDIR.replace(File.separatorChar, '/'));
        File dir;
        if (realPath != null) {
            dir = new File(realPath);
        } else {
            // Fallback to user home directory if getRealPath returns null
            dir = new File(System.getProperty("user.home"), ".ems_task_uploads");
        }
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return dir;
    }

    /**
     * Saves a single uploaded Part to disk and returns the generated filename.
     */
    public static String saveUploadedFile(Part part, ServletContext ctx, String prefix) throws IOException {
        if (part == null || part.getSize() <= 0) return null;

        String submittedName = Paths.get(part.getSubmittedFileName()).getFileName().toString();
        if (submittedName == null || submittedName.trim().isEmpty()) return null;

        String cleanName = submittedName.replaceAll("[^a-zA-Z0-9._-]", "_");
        String finalName = prefix + "_" + System.currentTimeMillis() + "_" + cleanName;

        File uploadDir = getUploadDirectory(ctx);
        File targetFile = new File(uploadDir, finalName);

        try (InputStream in = part.getInputStream()) {
            Files.copy(in, targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
        }

        return finalName;
    }

    /**
     * Saves multiple parts matching partName or partName + "[]",
     * enforcing the maxTotalBytes cumulative limit across all uploaded files.
     */
    public static List<String> saveUploadedFiles(HttpServletRequest req, String partName, ServletContext ctx, String prefix, long maxTotalBytes) throws IOException {
        Collection<Part> parts;
        try {
            parts = req.getParts();
        } catch (Exception e) {
            return Collections.emptyList();
        }

        if (parts == null || parts.isEmpty()) {
            return Collections.emptyList();
        }

        List<Part> matchedParts = new ArrayList<>();
        long totalBytes = 0L;

        for (Part p : parts) {
            if (p != null && (p.getName().equals(partName) || p.getName().equals(partName + "[]") || p.getName().startsWith(partName))) {
                if (p.getSize() > 0 && p.getSubmittedFileName() != null && !p.getSubmittedFileName().trim().isEmpty()) {
                    totalBytes += p.getSize();
                    matchedParts.add(p);
                }
            }
        }

        if (matchedParts.isEmpty()) {
            return Collections.emptyList();
        }

        if (maxTotalBytes > 0 && totalBytes > maxTotalBytes) {
            throw new IllegalArgumentException("Total uploaded file size (" + formatBytes(totalBytes) + ") exceeds the maximum allowed limit of " + formatBytes(maxTotalBytes) + ".");
        }

        List<String> savedNames = new ArrayList<>();
        File uploadDir = getUploadDirectory(ctx);

        for (int i = 0; i < matchedParts.size(); i++) {
            Part p = matchedParts.get(i);
            String submittedName = Paths.get(p.getSubmittedFileName()).getFileName().toString();
            String cleanName = submittedName.replaceAll("[^a-zA-Z0-9._-]", "_");
            String finalName = prefix + "_" + System.currentTimeMillis() + "_" + (i + 1) + "_" + cleanName;
            File targetFile = new File(uploadDir, finalName);

            try (InputStream in = p.getInputStream()) {
                Files.copy(in, targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            }
            savedNames.add(finalName);
        }

        return savedNames;
    }

    public static String joinFileNames(List<String> files) {
        if (files == null || files.isEmpty()) return null;
        return String.join(",", files);
    }

    public static List<String> splitFileNames(String joined) {
        if (joined == null || joined.trim().isEmpty()) return Collections.emptyList();
        String[] arr = joined.split("[,;]");
        List<String> res = new ArrayList<>();
        for (String s : arr) {
            String c = s.trim();
            if (!c.isEmpty()) res.add(c);
        }
        return res;
    }

    public static String getOriginalFileName(String storedFileName) {
        if (storedFileName == null || storedFileName.trim().isEmpty()) return "";
        String clean = Paths.get(storedFileName).getFileName().toString();
        // Remove prefix_<timestamp>_<index>_
        return clean.replaceFirst("^[a-zA-Z0-9]+_\\d+(_\\d+)?_", "");
    }

    public static String formatBytes(long bytes) {
        if (bytes < 1024) return bytes + " B";
        int exp = (int) (Math.log(bytes) / Math.log(1024));
        String pre = ("KMGTPE").charAt(exp - 1) + "";
        return String.format("%.1f %sB", bytes / Math.pow(1024, exp), pre);
    }

    /**
     * Resolves a file from the upload directory given its stored filename.
     */
    public static File getFile(ServletContext ctx, String filename) {
        if (filename == null || filename.trim().isEmpty()) return null;
        String clean = Paths.get(filename).getFileName().toString();
        File uploadDir = getUploadDirectory(ctx);
        File f = new File(uploadDir, clean);
        return f.exists() ? f : null;
    }
}

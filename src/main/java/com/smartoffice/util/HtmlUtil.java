package com.smartoffice.util;

public class HtmlUtil {

    public static String esc(Object obj) {
        if (obj == null) return "";
        String s = String.valueOf(obj);
        StringBuilder out = new StringBuilder(Math.max(16, s.length()));
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '&':
                    out.append("&amp;");
                    break;
                case '<':
                    out.append("&lt;");
                    break;
                case '>':
                    out.append("&gt;");
                    break;
                case '"':
                    out.append("&quot;");
                    break;
                case '\'':
                    out.append("&#x27;");
                    break;
                default:
                    out.append(c);
            }
        }
        return out.toString();
    }
}

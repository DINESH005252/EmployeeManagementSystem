package com.smartoffice.util;

public class PayrollException extends RuntimeException {
    private static final long serialVersionUID = 1L;

    public PayrollException(String message) {
        super(message);
    }

    public PayrollException(String message, Throwable cause) {
        super(message, cause);
    }
}

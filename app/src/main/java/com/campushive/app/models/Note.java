package com.campushive.app.models;

import java.util.Date;

public class Note {
    private String noteId;
    private String title;
    private String subject;
    private String fileUrl;
    private String uploadedBy;
    private String uploadedById;
    private Date timestamp;

    public Note() {} // Required empty constructor for Firebase

    public Note(String noteId, String title, String subject, String fileUrl, String uploadedBy, String uploadedById, Date timestamp) {
        this.noteId = noteId;
        this.title = title;
        this.subject = subject;
        this.fileUrl = fileUrl;
        this.uploadedBy = uploadedBy;
        this.uploadedById = uploadedById;
        this.timestamp = timestamp;
    }

    public String getNoteId() { return noteId; }
    public String getTitle() { return title; }
    public String getSubject() { return subject; }
    public String getFileUrl() { return fileUrl; }
    public String getUploadedBy() { return uploadedBy; }
    public String getUploadedById() { return uploadedById; }
    public Date getTimestamp() { return timestamp; }
}

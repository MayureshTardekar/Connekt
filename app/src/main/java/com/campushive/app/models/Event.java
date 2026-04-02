package com.campushive.app.models;

import java.util.Date;

public class Event {
    private String eventId;
    private String title;
    private String description;
    private String imageUrl; 
    private Date eventDate;
    private String createdBy;
    private Date timestamp;

    public Event() {} // Required empty constructor for Firebase

    public Event(String eventId, String title, String description, String imageUrl, Date eventDate, String createdBy, Date timestamp) {
        this.eventId = eventId;
        this.title = title;
        this.description = description;
        this.imageUrl = imageUrl;
        this.eventDate = eventDate;
        this.createdBy = createdBy;
        this.timestamp = timestamp;
    }

    public String getEventId() { return eventId; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getImageUrl() { return imageUrl; }
    public Date getEventDate() { return eventDate; }
    public String getCreatedBy() { return createdBy; }
    public Date getTimestamp() { return timestamp; }
}

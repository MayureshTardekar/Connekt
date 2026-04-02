package com.campushive.app.models;

import java.util.Date;

public class LostItem {
    private String itemId;
    private String itemName;
    private String description;
    private String location;
    private String imageUrl;
    private String status; // "LOST" or "FOUND"
    private String reportedBy;
    private Date timestamp;

    public LostItem() {} // Required empty constructor

    public LostItem(String itemId, String itemName, String description, String location, String imageUrl, String status, String reportedBy, Date timestamp) {
        this.itemId = itemId;
        this.itemName = itemName;
        this.description = description;
        this.location = location;
        this.imageUrl = imageUrl;
        this.status = status;
        this.reportedBy = reportedBy;
        this.timestamp = timestamp;
    }

    public String getItemId() { return itemId; }
    public String getItemName() { return itemName; }
    public String getDescription() { return description; }
    public String getLocation() { return location; }
    public String getImageUrl() { return imageUrl; }
    public String getStatus() { return status; }
    public String getReportedBy() { return reportedBy; }
    public Date getTimestamp() { return timestamp; }
}

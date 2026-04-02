package com.campushive.app.models;

import java.util.Date;
import java.util.List;

public class StudyGroup {
    private String groupId;
    private String subject;
    private String description;
    private Date dateTime;
    private String location;
    private String createdBy;
    private String createdById;
    private int maxMembers;
    private int memberCount;
    private List<String> members;

    public StudyGroup() {}

    public StudyGroup(String groupId, String subject, String description, Date dateTime, String location, String createdBy, String createdById, int maxMembers, int memberCount, List<String> members) {
        this.groupId = groupId;
        this.subject = subject;
        this.description = description;
        this.dateTime = dateTime;
        this.location = location;
        this.createdBy = createdBy;
        this.createdById = createdById;
        this.maxMembers = maxMembers;
        this.memberCount = memberCount;
        this.members = members;
    }

    public String getGroupId() { return groupId; }
    public String getSubject() { return subject; }
    public String getDescription() { return description; }
    public Date getDateTime() { return dateTime; }
    public String getLocation() { return location; }
    public String getCreatedBy() { return createdBy; }
    public String getCreatedById() { return createdById; }
    public int getMaxMembers() { return maxMembers; }
    public int getMemberCount() { return memberCount; }
    public List<String> getMembers() { return members; }
}

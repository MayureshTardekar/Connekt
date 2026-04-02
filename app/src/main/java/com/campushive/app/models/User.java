package com.campushive.app.models;

import java.util.Date;

public class User {
    private String uid;
    private String name;
    private String email;
    private Date createdAt;

    // Required empty constructor for Firebase
    public User() { } 

    public User(String uid, String name, String email, Date createdAt) {
        this.uid = uid;
        this.name = name;
        this.email = email;
        this.createdAt = createdAt;
    }

    public String getUid() { return uid; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public Date getCreatedAt() { return createdAt; }
}

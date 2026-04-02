package com.campushive.app.models;

import java.util.Date;

public class AnonPost {
    private String postId;
    private String content;
    private String tag; // "Vent", "Confession", "Question"
    private int upvotes;
    private Date timestamp;
    private String authorAlias; // Randomized string

    public AnonPost() {} // Firebase requirement

    public AnonPost(String postId, String content, String tag, int upvotes, Date timestamp, String authorAlias) {
        this.postId = postId;
        this.content = content;
        this.tag = tag;
        this.upvotes = upvotes;
        this.timestamp = timestamp;
        this.authorAlias = authorAlias;
    }

    public String getPostId() { return postId; }
    public String getContent() { return content; }
    public String getTag() { return tag; }
    public int getUpvotes() { return upvotes; }
    public Date getTimestamp() { return timestamp; }
    public String getAuthorAlias() { return authorAlias; }
}

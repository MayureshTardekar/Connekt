package com.campushive.app.models;

import java.util.Date;

public class ChatMessage {
    private String messageId;
    private String senderId;
    private String receiverId;
    private String text;
    private Date timestamp;

    public ChatMessage() {} // Required for Firebase

    public ChatMessage(String messageId, String senderId, String receiverId, String text, Date timestamp) {
        this.messageId = messageId;
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.text = text;
        this.timestamp = timestamp;
    }

    public String getMessageId() { return messageId; }
    public String getSenderId() { return senderId; }
    public String getReceiverId() { return receiverId; }
    public String getText() { return text; }
    public Date getTimestamp() { return timestamp; }
}

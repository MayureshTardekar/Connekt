package com.campushive.app.activities;

import android.os.Bundle;
import android.widget.EditText;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.adapters.ChatRoomAdapter;
import com.campushive.app.models.ChatMessage;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class ChatRoomActivity extends AppCompatActivity {

    private TextView tvChatPartner;
    private RecyclerView recyclerView;
    private EditText etInput;
    private FloatingActionButton fabSend;

    private ChatRoomAdapter adapter;
    private List<ChatMessage> messageList;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat_room);

        tvChatPartner = findViewById(R.id.tvChatPartner);
        recyclerView = findViewById(R.id.recyclerViewMessages);
        etInput = findViewById(R.id.etMessageInput);
        fabSend = findViewById(R.id.fabSend);

        // Name passed from ChatList
        String partnerName = getIntent().getStringExtra("CHAT_PARTNER_NAME");
        if (partnerName != null) tvChatPartner.setText(partnerName);

        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        // Important for chat styling to build bottom-up naturally (optional)
        layoutManager.setStackFromEnd(true);
        recyclerView.setLayoutManager(layoutManager);

        messageList = new ArrayList<>();
        // Mock default messages
        messageList.add(new ChatMessage("1", "OTHER_USER", "CURRENT_USER", "Hey, do you have notes for Physics?", new Date()));
        messageList.add(new ChatMessage("2", "CURRENT_USER", "OTHER_USER", "Yes! Just uploaded them.", new Date()));

        adapter = new ChatRoomAdapter(this, messageList);
        recyclerView.setAdapter(adapter);

        fabSend.setOnClickListener(v -> {
            String txt = etInput.getText().toString().trim();
            if (!txt.isEmpty()) {
                // Instantly append sent message to UI (Firebase logic will go here)
                messageList.add(new ChatMessage(String.valueOf(System.currentTimeMillis()), "CURRENT_USER", "OTHER_USER", txt, new Date()));
                adapter.notifyItemInserted(messageList.size() - 1);
                recyclerView.smoothScrollToPosition(messageList.size() - 1);
                etInput.setText("");
            }
        });
    }
}

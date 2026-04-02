package com.campushive.app.activities;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.adapters.ChatListAdapter;
import java.util.ArrayList;
import java.util.List;

public class ChatListActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private ChatListAdapter adapter;
    private List<String> mockChats;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat_list);

        recyclerView = findViewById(R.id.recyclerViewChatList);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        mockChats = new ArrayList<>();
        mockChats.add("Suresh Sharma");
        mockChats.add("Rahul Physics 101");
        mockChats.add("Campus Admin");

        adapter = new ChatListAdapter(this, mockChats);
        recyclerView.setAdapter(adapter);
    }
}

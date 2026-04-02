package com.campushive.app.activities;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.adapters.AnonFeedAdapter;
import com.campushive.app.models.AnonPost;
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class AnonFeedActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private AnonFeedAdapter adapter;
    private List<AnonPost> postList;
    private ExtendedFloatingActionButton fabAnonPost;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_anon_feed);

        recyclerView = findViewById(R.id.recyclerViewAnon);
        fabAnonPost = findViewById(R.id.fabAnonPost);

        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        postList = new ArrayList<>();
        // Mock data to visualize the neon theme
        postList.add(new AnonPost("1", "I accidentally fell asleep in the front row of Java class. The prof asked me a question right when I woke up and I answered with 'System out print'.", "Confession", 145, new Date(), "Ghost_194"));
        postList.add(new AnonPost("2", "Why is the wifi in Block B always down past 11PM? Are they rationing internet now?", "Rant", 32, new Date(), "Ghost_881"));

        adapter = new AnonFeedAdapter(this, postList);
        recyclerView.setAdapter(adapter);

        fabAnonPost.setOnClickListener(v -> {
            startActivity(new Intent(AnonFeedActivity.this, CreateAnonPostActivity.class));
        });
        
        // Firestore real-time listener targeting the "anonymous_feed" collection will go here
    }
}

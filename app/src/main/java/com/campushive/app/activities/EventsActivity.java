package com.campushive.app.activities;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.adapters.EventsAdapter;
import com.campushive.app.models.Event;
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class EventsActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private EventsAdapter adapter;
    private List<Event> eventList;
    private ExtendedFloatingActionButton fabAddEvent;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_events);

        recyclerView = findViewById(R.id.recyclerViewEvents);
        fabAddEvent = findViewById(R.id.fabAddEvent);

        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        eventList = new ArrayList<>();
        // Mock data to test UI
        eventList.add(new Event("1", "Hackathon 2026", "24-hour coding sprint inside the campus library.", "", new Date(), "Admin", new Date()));

        adapter = new EventsAdapter(this, eventList);
        recyclerView.setAdapter(adapter);

        fabAddEvent.setOnClickListener(v -> {
            startActivity(new Intent(EventsActivity.this, AddEventActivity.class));
        });
        
        // Firestore real-time listener will be placed here
    }
}

package com.campushive.app.activities;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.adapters.LostFoundAdapter;
import com.campushive.app.models.LostItem;
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class LostFoundActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private LostFoundAdapter adapter;
    private List<LostItem> itemList;
    private ExtendedFloatingActionButton fabReportItem;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_lost_found);

        recyclerView = findViewById(R.id.recyclerViewLostFound);
        fabReportItem = findViewById(R.id.fabReportItem);

        // 2-Column Grid Layout for a modern pinboard style
        recyclerView.setLayoutManager(new GridLayoutManager(this, 2));

        itemList = new ArrayList<>();
        // Mock data to test UI
        itemList.add(new LostItem("1", "AirPods Pro", "White case with scratches.", "Library", "", "LOST", "UserA", new Date()));
        itemList.add(new LostItem("2", "Casio Watch", "Silver chain watch.", "Gym", "", "FOUND", "UserB", new Date()));

        adapter = new LostFoundAdapter(this, itemList);
        recyclerView.setAdapter(adapter);

        fabReportItem.setOnClickListener(v -> {
            startActivity(new Intent(LostFoundActivity.this, ReportItemActivity.class));
        });
        
        // Firestore real-time listener will be placed here
    }
}

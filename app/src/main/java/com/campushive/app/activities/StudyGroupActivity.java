package com.campushive.app.activities;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.adapters.StudyGroupAdapter;
import com.campushive.app.models.StudyGroup;
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class StudyGroupActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private StudyGroupAdapter adapter;
    private List<StudyGroup> groupList;
    private ExtendedFloatingActionButton fabCreate;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_study_groups);

        Toolbar toolbar = findViewById(R.id.toolbarStudyGroups);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }
        toolbar.setNavigationOnClickListener(v -> finish());

        recyclerView = findViewById(R.id.recyclerViewGroups);
        fabCreate = findViewById(R.id.fabCreateGroup);

        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        groupList = new ArrayList<>();
        // Mock data
        groupList.add(new StudyGroup("g1", "Data Structures", "Revising Trees and Graphs for the upcoming practical.", new Date(), "Canteen Area", "Alex", "uid_1", 4, 3, new ArrayList<>()));
        groupList.add(new StudyGroup("g2", "DBMS Project", "Need 1 more person who knows SQL.", new Date(), "Library Block B", "Sarah", "uid_2", 3, 3, new ArrayList<>())); // Full

        adapter = new StudyGroupAdapter(this, groupList);
        recyclerView.setAdapter(adapter);

        fabCreate.setOnClickListener(v -> {
            startActivity(new Intent(StudyGroupActivity.this, CreateGroupActivity.class));
        });
    }
}

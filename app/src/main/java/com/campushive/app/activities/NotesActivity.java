package com.campushive.app.activities;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.adapters.NotesAdapter;
import com.campushive.app.models.Note;
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton;
import java.util.ArrayList;
import java.util.List;

public class NotesActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private NotesAdapter adapter;
    private List<Note> noteList;
    private ExtendedFloatingActionButton fabUpload;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_notes);

        recyclerView = findViewById(R.id.recyclerViewNotes);
        fabUpload = findViewById(R.id.fabUploadNote);

        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        
        // Mock data since backend is temporarily decoupled
        noteList = new ArrayList<>();
        // noteList.add(new Note("1", "Physics Chapter 1", "Physics", "url", "John", "123", new Date()));

        adapter = new NotesAdapter(this, noteList);
        recyclerView.setAdapter(adapter);

        fabUpload.setOnClickListener(v -> {
            startActivity(new Intent(NotesActivity.this, UploadNoteActivity.class));
        });
        
        // Firestore real-time listener will go here.
    }
}

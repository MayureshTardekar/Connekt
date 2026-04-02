package com.campushive.app.adapters;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.models.Note;
import java.util.List;

public class NotesAdapter extends RecyclerView.Adapter<NotesAdapter.NoteViewHolder> {

    private List<Note> noteList;
    private Context context;

    public NotesAdapter(Context context, List<Note> noteList) {
        this.context = context;
        this.noteList = noteList;
    }

    @NonNull
    @Override
    public NoteViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_note, parent, false);
        return new NoteViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull NoteViewHolder holder, int position) {
        Note note = noteList.get(position);
        
        holder.tvTitle.setText(note.getTitle());
        holder.tvSubject.setText(note.getSubject());
        holder.tvUploader.setText("By " + note.getUploadedBy());

        // Open PDF Link in Browser or external PDF Viewer
        holder.itemView.setOnClickListener(v -> {
            if(note.getFileUrl() != null && !note.getFileUrl().isEmpty()){
                Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(note.getFileUrl()));
                context.startActivity(intent);
            }
        });
    }

    @Override
    public int getItemCount() {
        return noteList.size();
    }

    public static class NoteViewHolder extends RecyclerView.ViewHolder {
        TextView tvTitle, tvSubject, tvUploader;

        public NoteViewHolder(@NonNull View itemView) {
            super(itemView);
            tvTitle = itemView.findViewById(R.id.tvNoteTitle);
            tvSubject = itemView.findViewById(R.id.tvNoteSubject);
            tvUploader = itemView.findViewById(R.id.tvUploader);
        }
    }
}

package com.campushive.app.adapters;

import android.content.Context;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.models.StudyGroup;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Locale;

public class StudyGroupAdapter extends RecyclerView.Adapter<StudyGroupAdapter.GroupViewHolder> {

    private List<StudyGroup> groupList;
    private Context context;

    public StudyGroupAdapter(Context context, List<StudyGroup> groupList) {
        this.context = context;
        this.groupList = groupList;
    }

    @NonNull
    @Override
    public GroupViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_study_group, parent, false);
        return new GroupViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull GroupViewHolder holder, int position) {
        StudyGroup group = groupList.get(position);
        
        holder.tvSubject.setText(group.getSubject());
        holder.tvDesc.setText(group.getDescription());
        holder.tvLocation.setText(group.getLocation());
        
        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, hh:mm a", Locale.getDefault());
        holder.tvDate.setText(sdf.format(group.getDateTime()));

        String capacity = group.getMemberCount() + "/" + group.getMaxMembers();
        holder.tvCapacity.setText(capacity);

        if (group.getMemberCount() >= group.getMaxMembers()) {
            holder.tvCapacity.setText("FULL");
            holder.tvCapacity.setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.parseColor("#EF4444"))); // Red
            holder.btnJoin.setEnabled(false);
            holder.btnJoin.setText("Closed");
        } else {
            holder.tvCapacity.setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.parseColor("#10B981"))); // Green
            holder.btnJoin.setEnabled(true);
            holder.btnJoin.setText("Join");
        }

        holder.btnJoin.setOnClickListener(v -> {
            Toast.makeText(context, "Joined Group! (Mocked)", Toast.LENGTH_SHORT).show();
            // In Phase 9 real impl: write to Firebase to add UID to array
        });
    }

    @Override
    public int getItemCount() {
        return groupList.size();
    }

    public static class GroupViewHolder extends RecyclerView.ViewHolder {
        TextView tvSubject, tvDesc, tvDate, tvLocation, tvCapacity;
        Button btnJoin;

        public GroupViewHolder(@NonNull View itemView) {
            super(itemView);
            tvSubject = itemView.findViewById(R.id.tvGroupSubject);
            tvDesc = itemView.findViewById(R.id.tvGroupDesc);
            tvDate = itemView.findViewById(R.id.tvGroupDate);
            tvLocation = itemView.findViewById(R.id.tvGroupLocation);
            tvCapacity = itemView.findViewById(R.id.tvGroupCapacity);
            btnJoin = itemView.findViewById(R.id.btnJoinGroup);
        }
    }
}

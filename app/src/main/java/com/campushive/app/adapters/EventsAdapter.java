package com.campushive.app.adapters;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.campushive.app.R;
import com.campushive.app.models.Event;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Locale;

public class EventsAdapter extends RecyclerView.Adapter<EventsAdapter.EventViewHolder> {

    private List<Event> eventList;
    private Context context;
    private SimpleDateFormat sdf;

    public EventsAdapter(Context context, List<Event> eventList) {
        this.context = context;
        this.eventList = eventList;
        this.sdf = new SimpleDateFormat("MMM dd, yyyy - hh:mm a", Locale.getDefault());
    }

    @NonNull
    @Override
    public EventViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_event, parent, false);
        return new EventViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull EventViewHolder holder, int position) {
        Event event = eventList.get(position);
        
        holder.tvTitle.setText(event.getTitle());
        holder.tvDesc.setText(event.getDescription());
        
        if (event.getEventDate() != null) {
            holder.tvDate.setText(sdf.format(event.getEventDate()));
        } else {
            holder.tvDate.setText("Date TBA");
        }

        if (event.getImageUrl() != null && !event.getImageUrl().isEmpty()) {
            holder.ivBanner.setVisibility(View.VISIBLE);
            Glide.with(context).load(event.getImageUrl()).into(holder.ivBanner);
        } else {
            // holder.ivBanner.setVisibility(View.GONE);
            // using a default gradient/color placeholder
            holder.ivBanner.setImageResource(android.R.color.darker_gray);
        }
    }

    @Override
    public int getItemCount() {
        return eventList.size();
    }

    public static class EventViewHolder extends RecyclerView.ViewHolder {
        TextView tvTitle, tvDate, tvDesc;
        ImageView ivBanner;

        public EventViewHolder(@NonNull View itemView) {
            super(itemView);
            tvTitle = itemView.findViewById(R.id.tvEventTitle);
            tvDate = itemView.findViewById(R.id.tvEventDate);
            tvDesc = itemView.findViewById(R.id.tvEventDesc);
            ivBanner = itemView.findViewById(R.id.ivEventBanner);
        }
    }
}

package com.campushive.app.adapters;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.campushive.app.R;
import com.campushive.app.models.LostItem;
import java.util.List;

public class LostFoundAdapter extends RecyclerView.Adapter<LostFoundAdapter.LFViewHolder> {

    private List<LostItem> itemList;
    private Context context;

    public LostFoundAdapter(Context context, List<LostItem> itemList) {
        this.context = context;
        this.itemList = itemList;
    }

    @NonNull
    @Override
    public LFViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_lost_found, parent, false);
        return new LFViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull LFViewHolder holder, int position) {
        LostItem item = itemList.get(position);
        
        holder.tvItemName.setText(item.getItemName());
        holder.tvLocation.setText(item.getLocation());
        holder.tvStatusBadge.setText(item.getStatus());

        // Dynamic Badge Coloring
        GradientDrawable bgShape = (GradientDrawable) holder.tvStatusBadge.getBackground();
        if ("LOST".equalsIgnoreCase(item.getStatus())) {
            bgShape.setColor(Color.parseColor("#EF4444")); // Red tone
        } else {
            bgShape.setColor(Color.parseColor("#10B981")); // Emerald Green tone
        }

        if (item.getImageUrl() != null && !item.getImageUrl().isEmpty()) {
            Glide.with(context).load(item.getImageUrl()).into(holder.ivItemImage);
        } else {
            holder.ivItemImage.setImageResource(android.R.drawable.ic_menu_gallery);
        }
    }

    @Override
    public int getItemCount() {
        return itemList.size();
    }

    public static class LFViewHolder extends RecyclerView.ViewHolder {
        TextView tvItemName, tvLocation, tvStatusBadge;
        ImageView ivItemImage;

        public LFViewHolder(@NonNull View itemView) {
            super(itemView);
            tvItemName = itemView.findViewById(R.id.tvItemName);
            tvLocation = itemView.findViewById(R.id.tvLocation);
            tvStatusBadge = itemView.findViewById(R.id.tvStatusBadge);
            ivItemImage = itemView.findViewById(R.id.ivItemImage);
        }
    }
}

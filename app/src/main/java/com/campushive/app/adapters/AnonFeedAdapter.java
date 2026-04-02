package com.campushive.app.adapters;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.models.AnonPost;
import java.util.List;

public class AnonFeedAdapter extends RecyclerView.Adapter<AnonFeedAdapter.AnonViewHolder> {

    private List<AnonPost> postList;
    private Context context;

    public AnonFeedAdapter(Context context, List<AnonPost> postList) {
        this.context = context;
        this.postList = postList;
    }

    @NonNull
    @Override
    public AnonViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_anon_post, parent, false);
        return new AnonViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull AnonViewHolder holder, int position) {
        AnonPost post = postList.get(position);
        
        holder.tvAlias.setText(post.getAuthorAlias());
        holder.tvContent.setText(post.getContent());
        holder.tvTag.setText(post.getTag());
        holder.tvUpvotes.setText(String.valueOf(post.getUpvotes()));
    }

    @Override
    public int getItemCount() {
        return postList.size();
    }

    public static class AnonViewHolder extends RecyclerView.ViewHolder {
        TextView tvAlias, tvTag, tvContent, tvUpvotes;

        public AnonViewHolder(@NonNull View itemView) {
            super(itemView);
            tvAlias = itemView.findViewById(R.id.tvAnonAlias);
            tvTag = itemView.findViewById(R.id.tvAnonTag);
            tvContent = itemView.findViewById(R.id.tvAnonContent);
            tvUpvotes = itemView.findViewById(R.id.tvUpvotes);
        }
    }
}

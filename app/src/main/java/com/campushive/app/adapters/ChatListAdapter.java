package com.campushive.app.adapters;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.campushive.app.R;
import com.campushive.app.activities.ChatRoomActivity;
import de.hdodenhof.circleimageview.CircleImageView;
import java.util.List;

public class ChatListAdapter extends RecyclerView.Adapter<ChatListAdapter.ChatListViewHolder> {

    private Context context;
    private List<String> mockUserNames; // Replaced by User Model or ChatThread Model later

    public ChatListAdapter(Context context, List<String> mockUserNames) {
        this.context = context;
        this.mockUserNames = mockUserNames;
    }

    @NonNull
    @Override
    public ChatListViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_chat_preview, parent, false);
        return new ChatListViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ChatListViewHolder holder, int position) {
        String name = mockUserNames.get(position);
        holder.tvChatName.setText(name);

        holder.itemView.setOnClickListener(v -> {
            Intent intent = new Intent(context, ChatRoomActivity.class);
            intent.putExtra("CHAT_PARTNER_NAME", name);
            context.startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return mockUserNames.size();
    }

    public static class ChatListViewHolder extends RecyclerView.ViewHolder {
        CircleImageView ivAvatar;
        TextView tvChatName, tvLastMessage, tvTime;

        public ChatListViewHolder(@NonNull View itemView) {
            super(itemView);
            ivAvatar = itemView.findViewById(R.id.ivAvatar);
            tvChatName = itemView.findViewById(R.id.tvChatName);
            tvLastMessage = itemView.findViewById(R.id.tvLastMessage);
            tvTime = itemView.findViewById(R.id.tvTime);
        }
    }
}

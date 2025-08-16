package com.example.mymessenger.ui

class UserAdapter(
    private val users: List<User>,
    private val onItemClick: (User) -> Unit
) : RecyclerView.Adapter<UserAdapter.UserViewHolder>() {

    class UserViewHolder(val binding: UserItemBinding) : 
        RecyclerView.ViewHolder(binding.root)

        val binding = UserItemBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return UserViewHolder(binding)
    }

    override fun onBindViewHolder(holder: UserViewHolder, position: Int) {
        val user = users[position]
        holder.binding.userName.text = user.name
        holder.binding.callButton.setOnClickListener { onItemClick(user) }
    }

    override fun getItemCount() = users.size
}

module ApplicationHelper
  include Pagy::Frontend

  def flash_class(level)
    case level.to_sym
    when :notice
      'bg-blue-900 border-blue-900'
    when :success
      'bg-green-900 border-green-900'
    when :alert
      'bg-red-900 border-red-900'
    when :error
      'bg-red-900 border-red-900'
    else
      'bg-blue-900 border-blue-900'
    end
  end

  def post_body_preview(post, length: 200)
    truncate(post.body.to_plain_text, length: length)
  end

  def upvote_icon(user, discussion)
    if user.voted_up_on? discussion, vote_scope: 'like'
      'text-blue-600'
    else
      'text-gray-600'
    end
  end

  def downvote_icon(user, discussion)
    if user.voted_down_on? discussion, vote_scope: 'like'
      'text-blue-600'
    else
      'text-gray-600'
    end
  end
end

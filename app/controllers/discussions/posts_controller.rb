module Discussions
  class PostsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_discussion
    before_action :set_post, only: [:show, :edit, :update, :destroy]
    before_action :require_ownership!, only: [:edit, :update, :destroy]

    def create
      @post = @discussion.posts.new(post_params.merge(user: current_user))

      respond_to do |format|
        if @post.save
          format.html { redirect_to discussion_path(@discussion), notice: "Post created" }
        else
          format.turbo_stream
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def show
    end

    def edit
    end

    def update
      respond_to do |format|
        if @post.update(post_params)
          format.html { redirect_to @post.discussion, notice: "Post update" }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @post.destroy

      respond_to do |format|
        format.turbo_stream { } # let the callback delete the post
        format.html { redirect_to @post.discussion, notice: "Post deleted" }
      end
    end

    private

    def set_discussion
      @discussion = Discussion.find(params[:discussion_id])
    end

    def set_post
      @post = @discussion.posts.find(params[:id])
    end

    def require_ownership!
      redirect_to discussion_path(@discussion), alert: "You can't do that." unless @post.user == current_user
    end

    def post_params
      params.require(:post).permit(:body)
    end
  end
end

module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[ show edit update destroy ]

    # GET /admin/categories or /admin/categories.json
    def index
      @categories = Category.all
    end

    # GET /admin/categories/1 or /admin/categories/1.json
    def show
    end

    # GET /admin/categories/new
    def new
      @category = Category.new
    end

    # GET /admin/categories/1/edit
    def edit
    end

    # POST /admin/categories or /admin/categories.json
    def create
      @category = Category.new(category_params)

      respond_to do |format|
        if @category.save
          format.html { redirect_to admin_category_path(@category), notice: "Category was successfully created." }
          format.json { render :show, status: :created, location: @category }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @category.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /admin/categories/1 or /admin/categories/1.json
    def update
      respond_to do |format|
        if @category.update(category_params)
          format.html { redirect_to admin_category_path(@category), notice: "Category was successfully updated." }
          format.json { render :show, status: :ok, location: @category }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @category.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /admin/categories/1 or /admin/categories/1.json
    def destroy
      @category.destroy!

      respond_to do |format|
        format.html { redirect_to admin_categories_url, notice: "Category was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name)
    end
  end
end

require "csv"
module Partners
  class ChildrenController < BaseController
    layout 'partners/application'

    helper_method :sort_column, :sort_direction

    def index
      @filterrific = initialize_filterrific(
        current_partner.children
                       .includes(:family)
                       .order(sort_order),
        params[:filterrific]
      ) || return

      @children = @filterrific.find

      respond_to do |format|
        format.js
        format.html
        format.csv do
          render(csv: @children.map(&:to_csv))
        end
      end
      @family = current_partner.children
                               .includes(:family)
                               .order(active: :desc, last_name: :asc).collect(&:family).compact.uniq.sort
    end

    def show
      @child = current_partner.children.find_by(id: params[:id])
      @child_item_requests = @child
                             .child_item_requests
                             .includes(:item_request)
    end

    def new
      @child = family.children.new
    end

    def active
      child = current_partner.children.find(params[:child_id])
      child.active = !child.active
      child.save
    end

    def edit
      @child = current_partner.children.find_by(id: params[:id])
    end

    def create
      child = family.children.new(child_params)

      if child.save
        redirect_to child, notice: "Child was successfully created."
      else
        render :new
      end
    end

    def update
      child = current_partner.children.find_by(id: params[:id])

      if child.update(child_params)
        redirect_to child, notice: "Child was successfully updated."
      else
        render :edit
      end
    end

    private

    def family
      # temporarily disable this rubocop rule because we have an instance variable named @family elsewhere,
      # we should carefully test this before renaming it to @family
      # rubocop:disable Naming/MemoizedInstanceVariableName
      @_family ||= current_partner.families.find_by(id: params[:family_id])
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

    def child_params
      params.require(:partners_child).permit(
        :active,
        :agency_child_id,
        :comments,
        :date_of_birth,
        :first_name,
        :gender,
        :health_insurance,
        :item_needed_diaperid,
        :last_name,
        :race,
        :archived,
        child_lives_with: []
      )
    end

    def sort_order
      sort_column + ' ' + sort_direction
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    def sort_column
      Child.column_names.include?(params[:sort]) ? params[:sort] : "last_name"
    end
  end
end
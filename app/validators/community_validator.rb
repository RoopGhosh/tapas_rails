class CommunityValidator < TapasObjectValidator
  def required_attributes
    case params[:action]
    when "create"
      [:nid, :title, :members, :depositor, :access] 
    when "nid_update"
      []
    end
  end
end

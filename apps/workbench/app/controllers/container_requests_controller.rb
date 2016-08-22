class ContainerRequestsController < ApplicationController
  skip_around_filter :require_thread_api_token, if: proc { |ctrl|
    Rails.configuration.anonymous_user_token and
    'show' == ctrl.action_name
  }

  def show_pane_list
    panes = %w(Status Log Graph Advanced)
    if @object and @object.state == 'Uncommitted'
      panes = %w(Inputs) + panes - %w(Log)
    end
    panes
  end

  def cancel
    @object.update_attributes! priority: 0
    if params[:return_to]
      redirect_to params[:return_to]
    else
      redirect_to @object
    end
  end

  def update
    @updates ||= params[@object.class.to_s.underscore.singularize.to_sym]
    input_obj = @updates[:mounts].andand[:"/var/lib/cwl/cwl.input.json"].andand[:content]
    if input_obj
      workflow = @object.mounts[:"/var/lib/cwl/workflow.json"][:content]
      workflow[:inputs].each do |input_schema|
        if input_obj.include? input_schema[:id]
          required, primary_type, param_id = cwl_input_info(input_schema)
          if input_obj[param_id] == ""
            input_obj[param_id] = nil
          elsif primary_type == "boolean"
            input_obj[param_id] = input_obj[param_id] == "true"
          elsif ["int", "long"].include? primary_type
            input_obj[param_id] = input_obj[param_id].to_i
          elsif ["float", "double"].include? primary_type
            input_obj[param_id] = input_obj[param_id].to_f
          elsif ["File", "Directory"].include? primary_type
            input_obj[param_id].match /^([0-9a-z]{5}-([0-9a-z]{5})-[0-9a-z]{15})(\/.*)?$/ do |re|
              c = display_value = Collection.find(re[1])
              input_obj[param_id] = {"class" => primary_type,
                                     "location" => "keep:#{c.portable_data_hash}#{re[3]}",
                                     "arv:collection" => input_obj[param_id]}
            end
          end
        end
      end
    end
    params[:merge] = true
    super
  end

end

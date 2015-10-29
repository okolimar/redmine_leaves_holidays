class LeaveManagementRulesController < ApplicationController
  unloadable
  include LeavesHolidaysManagements
  before_action :find_project

  helper :leave_management_rules
  include LeaveManagementRulesHelper

  def new

    @sender_type = params[:sender_type] || LeavesHolidaysManagements.default_actor_type
    @sender_list_id ||= params[:sender_list_id]
    @sender_exception_id ||= params[:sender_exception_id]

    @action ||= params[:action_rule]
    
    @receiver_type = params[:receiver_type] || LeavesHolidaysManagements.default_actor_type
    @receiver_list_id ||= params[:receiver_list_id]
    @receiver_exception_id ||= params[:receiver_exception_id]
  end

  def create
    if params[:sender_list_id] && params[:receiver_list_id]
      params[:sender_list_id].each do |sender_id|
        params[:receiver_list_id].each do |receiver_id|
          @leave_management_rule = LeaveManagementRule.new(project: @project, sender: params[:sender_type].constantize.find(sender_id.to_i), receiver: params[:receiver_type].constantize.find(receiver_id.to_i), action: LeaveManagementRule.actions.select{|k,v| v == params[:action_rule].to_i}.keys.first)
          if @leave_management_rule.save
            if params[:sender_exception_id]
              params[:sender_exception_id].each do |sender_excpt|
                LeaveExceptionRule.create(leave_management_rule: @leave_management_rule, actor_concerned: :sender, user: User.find(sender_excpt.to_i))
              end
            end
            if params[:receiver_exception_id]
              params[:receiver_exception_id].each do |receiver_excpt|
                LeaveExceptionRule.create(leave_management_rule: @leave_management_rule, actor_concerned: :receiver, user: User.find(receiver_excpt.to_i))
              end
            end
          end
        end
      end
    end
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js {
        #redirect_to redirect_to_settings_in_projects #new_project_leave_management_rule_path
        }
    end
  end

  def edit
    management_rule_ids ||= params[:management_rule_ids]
    management_rules = LeaveManagementRule.where(id: management_rule_ids, project: @project)
    sender_exceptions = LeaveExceptionRule.where(leave_management_rule_id: management_rule_ids, actor_concerned: LeaveExceptionRule.actors_concerned[:sender])
    receiver_exceptions = LeaveExceptionRule.where(leave_management_rule_id: management_rule_ids, actor_concerned: LeaveExceptionRule.actors_concerned[:receiver])
    
    @sender_type = management_rules.first.sender_type
    @sender_list_id = management_rules.pluck(:sender_id)
    @sender_exception_id = sender_exceptions.pluck(:user_id)

    @action = management_rules.first.action
    
    @receiver_type = management_rules.first.receiver_type
    @receiver_list_id = management_rules.pluck(:receiver_id)
    @receiver_exception_id = receiver_exceptions.pluck(:user_id)
  end

  def index
    respond_to do |format|
      format.html { head 406 }
    end
  end

  private

  def find_project
    @project ||= Project.find(params[:project_id])
  end

  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'leave_management')
  end

end
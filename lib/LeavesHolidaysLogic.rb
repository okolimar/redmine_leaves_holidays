module LeavesHolidaysLogic

	def self.issues_list
		issues_tracker = RedmineLeavesHolidays::Setting.default_tracker_id
		issues_project = RedmineLeavesHolidays::Setting.default_project_id
		return Issue.where(project_id: issues_project, tracker_id: issues_tracker) #.collect{|t| [t.subject, t.id] }
	end

	def self.roles_list
		Role.find_all_givable.sort.collect{|t| [position: t.position, id: t.id, name: t.name] }
	end

	def self.plugin_admins
		RedmineLeavesHolidays::Setting.plugin_admins.map(&:to_i)
	end

	def self.has_manage_rights(user)
		self.plugin_admins.include?(user.id) || user.allowed_to?(:manage_leaves_requests, nil, :global => true)
	end

	def self.project_list_for_user(user)
		user.memberships.uniq.collect{|t| t.project_id}
	end

	def self.allowed_roles_for_user_for_project(user, project)
		allowed_roles = user.roles_for_project(project).sort.uniq
		allowed_roles.collect{|r| {position: r.position, allowed: r.allowed_to?(:manage_leaves_requests)}}
	end

	def self.is_allowed_to_view_request(user, request)
		return true if user.id == request.user.id
		return false if request.request_status == "created"
		return true if user.allowed_to?(:view_all_leaves_requests, nil, :global => true) || user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return true if self.plugin_admins.include?(user.id)
		false
	end

	def self.is_allowed_to_manage_request(user, request)
		return true if user.id == request.user.id #Only the creator of the request can change it
		false
	end

	def self.is_allowed_to_view_status(user, user_request)
		return true if user.id == user_request.id #A user can see the status of his own requests
		#A user with this right has access to all the leave request statuses
		return true if user.allowed_to?(:view_all_leaves_requests, nil, :global => true) || user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return true if self.plugin_admins.include?(user.id) 
		false
	end

	def self.is_allowed_to_manage_status(user, user_request)
		return true if self.plugin_admins.include?(user.id) #A plugin Admin can approve all the requests including his own requests
		return false if !user.allowed_to?(:manage_leaves_requests, nil, :global => true)
		return false if self.plugin_admins.include?(user_request.id) #User req is plugin admin and hence his role >>> user -> Disallow
		return false if user.id == user_request.id #Any non plugin admin cannot approve his own requests

		common_projects = self.project_list_for_user(user) & self.project_list_for_user(user_request)
		if !common_projects.empty?
			common_projects.each do |p|
				project = Project.find(p)
				array_roles_user = self.allowed_roles_for_user_for_project(user, project)
				array_roles_user_req = self.allowed_roles_for_user_for_project(user_request, project)
				array_roles_user.each do |role|
					return true if (role[:position] < array_roles_user_req.first[:position]) && role[:allowed]
				end
			end
			
		end
		false
	end

	#Returns a list of users which are able to approve a leave request
	def self.can_approve_request(user_request)
		users = User.where(status: 1)
		users = users.collect {|t| {uid: t.id, name: t.name}}

		users.delete_if { |u| 
			uobj = User.find(u[:uid])
			!self.is_allowed_to_manage_status(uobj, user_request)
		}
		return users
	end

	#Returns a list of users to notify of a leave request. 
	def self.users_to_notify(user_request)

	end

	def self.working_hours_per_week(user)

	end

	def self.max_leaves_days_per_year(user)

	end

end
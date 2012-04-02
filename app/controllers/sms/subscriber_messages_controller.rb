module Sms
	class SubscriberMessagesController < Admin::BaseController
		respond_to(:html)

		# list messages for subscriber
		def index
			@page = params[:page]

			@patient = Weltel::Patient.get!(params[:patient_id])

			@messages = @patient.subscriber.messages.search(@page, 6)

			respond_with(@patient, @messages)
		end

		# new message form for subscriber
		def new
			@patient = Weltel::Patient.get!(params[:patient_id])

			@message = @patient.subscriber.messages.new

			@message_body_options = message_body_options

			respond_with(@patient, @message)
		end

		# create a new message for subscriber
		def create
			begin
				@patient = Weltel::Patient.get!(params[:patient_id])

				if params[:message][:body].empty?
					body = t(params[:message_body])
				else
					body = params[:message][:body]
				end

				@message = Message.create_to_subscriber(@patient.subscriber, body)

				ProjectScope.current.factory.sender.send(@message)

				flash[:notice] = t(:message_created)

				respond_with(@message, :location => admin_weltel_patient_messages_path(@patient))

			rescue DataMapper::SaveFailureError => error
				@message = error.resource

				@message_body_options = message_body_options

				respond_with(@message) do |format|
					format.html { render(:new) }
				end
			end
		end

	private
		#
		def message_body_options
			[
				[t(:message_ok), :message_ok],
				[t(:message_not_ok), :message_not_ok],
				[t(:message_no_response), :message_no_response],
				[t(:message_no_answer), :message_no_answer],
				[t(:message_no_answer_again), :message_no_answer_again]
			]
		end
	end
end
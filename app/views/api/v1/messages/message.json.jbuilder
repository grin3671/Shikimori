json.id @resource.id
json.content JsExports::Supervisor.instance.sweep(
  current_user,
  render(
    partial: 'messages/message',
    object: @resource.decorate,
    formats: :html
  )
)
json.notice local_assigns[:notice]

json.JS_EXPORTS JsExports::Supervisor.instance.export(current_user)

json.content JsExports::Supervisor.instance.sweep(
  current_user,
  render(
    partial: 'characters/character',
    collection: @collection,
    formats: :html
  )
)

if @collection&.next_page?
  json.postloader render(
    partial: 'blocks/postloader',
    locals: {
      filter: 'b-catalog_entry',
      next_url: current_url(page: @collection.next_page),
      prev_url: (
        current_url(page: @collection.prev_page) if @collection.prev_page?
      ),
      pages_limit: 10
    },
    formats: :html
  )
end

json.JS_EXPORTS JsExports::Supervisor.instance.export(current_user)

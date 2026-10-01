module ApplicationHelper
  THRESHOLD_CELL_CLASSES = {
    alert: "bg-red-50 font-medium text-red-700",
    good: "bg-emerald-50 font-medium text-emerald-700"
  }.freeze

  def threshold_cell_classes(threshold_statuses, asset, kind)
    status = threshold_statuses.dig(asset.id, kind)

    THRESHOLD_CELL_CLASSES.fetch(status, "text-slate-700")
  end
end

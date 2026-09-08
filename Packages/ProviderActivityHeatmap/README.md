# ProviderActivityHeatmap

Defines the data contract used to display calendar-based Git activity. The package is UI- and source-agnostic: plugins provide `ActivityHeatmapSnapshot` values, expose refresh progress through `isLoading`, and may choose how to collect or persist them.

data.extend([
  {
    type: 'double-setting',
    name: 'coastal-erosion-erosion-tiles-rate',
    setting_type: 'startup',
    minimum_value: 0,
    maximum_value: 1,
    default_value: 0.05,
  },
  {
    type: 'int-setting',
    name: 'coastal-erosion-max-erosion-tiles',
    setting_type: 'startup',
    minimum_value: 1,
    default_value: 100,
  },
  {
    type: 'int-setting',
    name: 'coastal-erosion-erosion-speed',
    setting_type: 'startup',
    minimum_value: 10,
    default_value: 1000,
  },
  {
    type: 'bool-setting',
    name: 'coastal-erosion-debug-output',
    setting_type: 'runtime-per-user',
    default_value: false,
  },
]);

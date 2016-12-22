(function() {
  // The benchmarks that we want to display, in the order they should appear
  // on the plot axis.
  var benchmarks = [
    'Populate fields',
    'Encode binary', 'Decode binary',
    'Encode JSON', 'Decode JSON',
    'Encode text', 'Decode text',
    'Test equality',
  ];

  // The languages we have harnesses for. The results for each language will
  // appear as a series in the plot.
  var languages = ['Swift', 'C++'];

  // The harnessSize keys we want to print in the summary table, in the order
  // they should be displayed.
  var harnessSizeKeys = ['Unstripped', 'Stripped'];

  // Common layout properties for the plot.
  var layout = {
    boxmode: 'group',
    xaxis: {
      showgrid: false,
      showline: false,
      autotick: true,
      ticks: 'outside',
    },
    yaxis: {
      title: 'Runtime (ms)',
      autorange: true,
    },
    margin: {
      l: 60,
      r: 60,
      t: 0,
      b: 60,
    },
    font: {
      family: 'Helvetica',
    },
    hovermode: 'closest',
    legend: {
      font: {
        size: 12,
      },
      yanchor: 'middle',
      xanchor: 'right',
    },
  };

  // Creates and return a series for the given language's results in a session.
  function createSeries(session, language) {
    var x = [];
    var y = [];

    // The x-axis is categorical over the benchmark names. Adding the same
    // benchmark multiple times will collapse all the points on the same
    // vertical, which is what we want.
    for (var i = 0; i < benchmarks.length; i++) {
      var benchmark = benchmarks[i];
      var timings = session[language][benchmark];
      if (timings) {
        for (var j = 0; j < timings.length; j++) {
          x.push(benchmark.replace(" ", "<br>"));
          y.push(timings[j]);
        }
      }
    }

    return {
      name: language,
      x: x,
      y: y,
      type: 'box',
      boxpoints: 'all',
      whiskerwidth: 0.5,
      pointpos: 0,
      jitter: 0.3,
      mode: 'marker',
      marker: {
        symbol: 'circle',
        size: 8,
        opacity: 0.6,
      },
      line: {
        width: 1,
      },
    };
  }

  // Computes and returns the median of the given array of values.
  function median(values) {
    values.sort();
    var mid = Math.floor(values.length / 2);
    if (values.length % 2) {
      return values[mid];
    } else {
      return (values[mid - 1] + values[mid]) / 2.0;
    }
  }

  // Populates a multiplier cell with the ratio between the given two values
  // and sets its background color depending on the magnitude.
  function populateMultiplierCell(cell, language, swiftValue, otherValue) {
    if (language != 'Swift') {
      var multiplier = swiftValue / otherValue;

      if (multiplier < 1) {
        cell.text('(<1x)');
      } else {
        cell.text('(' + multiplier.toFixed(0) + 'x)');
      }

      if (multiplier < 3) {
        cssClass = 'bg-success';
      } else if (multiplier < 10) {
        cssClass = 'bg-warning';
      } else {
        cssClass = 'bg-danger';
      }
      cell.addClass(cssClass);
    }
  }

  // Creates and returns the summary table displayed next to the chart for a
  // given session.
  function createSummaryTable(session) {
    var table = $('<table></table>').addClass('table table-condensed numeric');
    var tbody = $('<tbody></tbody>').appendTo(table);

    // Insert the runtime stats.
    var header = $('<tr></tr>').appendTo(table);
    header.append($('<th>Median runtimes</th>'));
    for (var j = 0; j < languages.length; j++) {
      header.append($('<th></th>').text(languages[j]));
      header.append($('<th></th>'));
    }

    for (var i = 0; i < benchmarks.length; i++) {
      var benchmark = benchmarks[i];
      var tr = $('<tr></tr>')
      table.append(tr);
      tr.append($('<td></td>').text(benchmark));

      for (var j = 0; j < languages.length; j++) {
        var language = languages[j];

        var timings = session[language][benchmark];
        if (timings) {
          var med = median(timings);
          var formattedMedian = med.toFixed(3) + '&nbsp;ms';
          tr.append($('<td></td>').html(formattedMedian));

          var multiplierCell = $('<td></td>').appendTo(tr);
          var swiftMed = median(session['Swift'][benchmark]);
          populateMultiplierCell(multiplierCell, language, swiftMed, med);
        }
      }
    }

    // Insert the binary size stats.
    header = $('<tr></tr>').appendTo(table);
    header.append($('<th>Harness size</th>'));
    for (var j = 0; j < languages.length; j++) {
      header.append($('<th></th>'));
      header.append($('<th></th>'));
    }

    for (var i = 0; i < harnessSizeKeys.length; i++) {
      var harnessSizeKey = harnessSizeKeys[i];
      var tr = $('<tr></tr>')
      table.append(tr);
      tr.append($('<td></td>').text(harnessSizeKey));

      for (var j = 0; j < languages.length; j++) {
        var language = languages[j];

        var size = session[language].harnessSize[harnessSizeKey];
        var formattedSize = size.toLocaleString() + '&nbsp;b';
        tr.append($('<td></td>').html(formattedSize));

        var multiplierCell = $('<td></td>').appendTo(tr);
        var swiftSize = session['Swift'].harnessSize[harnessSizeKey];
        populateMultiplierCell(multiplierCell, language, swiftSize, size);
      }
    }

    var tfoot = $('<tfoot></tfoot>').appendTo(table);
    var footerRow = $('<tr></tr>').appendTo(tfoot);
    var colspan = 2 * languages.length + 1;
    var footerCell =
        $('<td colspan="' + colspan + '"></td>').appendTo(footerRow);
    footerCell.text('Multipliers indicate how much slower/larger the Swift ' +
        'harness is compared to the other language.');

    return table;
  }

  $(function() {
    if (!window.sessions) {
      return;
    }

    // Iterate the sessions in reverse order so that the most recent ones
    // appear at the top. We create one chart for each session and tile them
    // down the page.
    for (var i = sessions.length - 1; i >= 0; i--) {
      var session = sessions[i];
      var allSeries = [];

      formattedDate =
          moment(new Date(session.date)).format('MMM Do h:mm:ss a');
      var title = session.type;
      var header = $('<h3></h3>').addClass('row').text(title);

      var subtitle = 'Branch <tt>' + session.branch +
          '</tt>, commit <tt>' + session.commit + '</tt>';
      if (session.uncommitted_changes) {
        subtitle += ' (with uncommited changes)';
      }
      subtitle += ', run on ' + formattedDate;

      header.append($('<small></small>').html(subtitle));
      $('#container').append('<hr>');
      $('#container').append(header);

      var id = 'chart' + i;
      var row = $('<div></div>').addClass('row');
      var chartColumn = $('<div></div>').addClass('col-md-9');
      var tableColumn = $('<div></div>').addClass('col-md-3');

      row.append(chartColumn);
      row.append(tableColumn);
      $('#container').append(row);

      var chart = $('<div></div>').attr('id', id).addClass('chart');
      chartColumn.append(chart);

      for (var j = 0; j < languages.length; j++) {
        var language = languages[j];
        if (session[language]) {
          var series = createSeries(session, language);
          allSeries.push(series);
        }
      }

      Plotly.newPlot(id, allSeries, layout, {
        displayModeBar: false,
      });

      var table = createSummaryTable(session);
      tableColumn.append(table);
    }

    window.onresize = function() {
      $('.chart').each(function() {
        Plotly.Plots.resize(this);
      });
    };
  });
})();

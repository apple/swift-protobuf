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

  // Common layout properties for the plot.
  var layout = {
    xaxis: {
      showgrid: false,
      showline: false,
      autotick: true,
      ticks: 'outside',
    },
    yaxis: {
      title: 'Runtime (ms)',
    },
    margin: {
      l: 60,
      r: 60,
      t: 60,
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
      xanchor: 'right'
    },
  };

  // Create and return a series for the given language's results in a session.
  function getSeries(session, language) {
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
    return { name: language, x: x, y: y };
  }

  $(function() {
    // Iterate the sessions in reverse order so that the most recent ones
    // appear at the top. We create one chart for each session and tile them
    // down the page.
    for (var i = sessions.length - 1; i >= 0; i--) {
      var session = sessions[i];
      var allSeries = [];

      var id = 'chart' + i;
      var div = $('<div></div>').attr('id', id).addClass('chart');
      $('body').append(div);

      for (var j = 0; j < languages.length; j++) {
        var language = languages[j];
        if (session[language]) {
          var series = getSeries(session, language);

          formattedDate =
              moment(new Date(session.date)).format('MMM Do h:mm:ss a');
          layout.title = session.type + ": " + formattedDate;
          series.type = 'scatter';
          series.mode = 'markers';
          series.marker = {
            symbol: 'circle',
            size: 8,
          };

          allSeries.push(series);
        }
      }

      Plotly.newPlot(id, allSeries, layout, {
        displayModeBar: false,
      });
    }
  });
})();

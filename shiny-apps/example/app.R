# Example Shiny app: a normal-distribution density curve driven by
# numericInput boxes below the plot. Axis limits are fixed so the layout
# never jumps as inputs change. Embedded in posts via the `shiny` shortcode,
# e.g. {{< shiny app="example" height="650" >}}

library(shiny)
library(ggplot2)
library(plotly)

X_LIM <- c(-20, 20)
Y_LIM <- c(0, 0.6)

ui <- fluidPage(
  plotlyOutput("densityPlot", height = "450px"),
  fluidRow(
    column(4, numericInput("mean", "Mean", value = 0, min = -15, max = 15, step = 0.5)),
    column(4, numericInput("sd", "Standard deviation", value = 1, min = 0.1, max = 10, step = 0.1)),
    column(4, numericInput("n", "Sample size (n)", value = 500, min = 10, max = 5000, step = 10))
  )
)

server <- function(input, output, session) {
  output$densityPlot <- renderPlotly({
    mean_val <- input$mean
    sd_val <- max(input$sd, 1e-6)
    n_val <- input$n

    set.seed(42)
    x <- seq(X_LIM[1], X_LIM[2], length.out = 400)
    density_df <- data.frame(x = x, y = dnorm(x, mean = mean_val, sd = sd_val))
    sample_df <- data.frame(sample = rnorm(n_val, mean = mean_val, sd = sd_val))

    p <- ggplot() +
      geom_histogram(
        data = sample_df, aes(x = sample, y = after_stat(density)),
        bins = 40, fill = "#7aa7ff", alpha = 0.5, color = NA
      ) +
      geom_line(data = density_df, aes(x = x, y = y), color = "#1a56db", linewidth = 1) +
      coord_cartesian(xlim = X_LIM, ylim = Y_LIM) +
      labs(x = "Value", y = "Density", title = sprintf("N(%.1f, %.1f), n = %d", mean_val, sd_val, n_val)) +
      theme_minimal()

    ggplotly(p) %>% layout(margin = list(t = 50))
  })
}

shinyApp(ui, server)

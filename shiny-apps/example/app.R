# Example Shiny app: a normal-distribution density curve driven by
# numericInput boxes below the plot. Axis limits are fixed so the layout
# never jumps as inputs change. Embedded in posts via the `shiny` shortcode,
# e.g. {{< shiny app="example" height="650" >}}

library(shiny)
library(bslib)
library(ggplot2)
library(tibble)

ui <- page_fluid(
  sliderInput(
    "n_bins",
    label = "number of bins",
    min = 5,
    max = 30,
    value = 15
  ),
  numericInput(
    "n",
    label = "sample size",
    min = 1, max = 10000, step = 1,
    value = 50
  ),
  numericInput(
    "mu",
    label = "mean",
    min = -100, max = 100, step = 1,
    value = 0
    ),
  numericInput(
    "sd",
    label = "standard deviation",
    min = 0, max = 20, step = 0.1,
    value = 1
  ),
  plotOutput("plot")
)

server <- function(input, output) {
  output$plot <- renderPlot( 
    {
      vals <- tibble(val = rnorm(input$n, input$mu, max(input$sd, 0)))
      ggplot(data = vals, aes(val)) +
        theme_classic(base_size = 12, base_family = "serif") +
        geom_histogram(bins = input$n_bins) 
    } 
  ) 
}

shinyApp(ui = ui, server = server)

document.addEventListener("DOMContentLoaded", () => {
  const engineSelect = document.getElementById("engineSelect");
  const buttons = document.querySelectorAll("button[data-query-id]");
  const timeDisplay = document.getElementById("time");
  const resultDisplay = document.getElementById("resultJson");

  // Limpiar salida al cambiar el motor
  engineSelect.addEventListener("change", () => {
    timeDisplay.textContent = "";
    resultDisplay.textContent = "";
  });

  buttons.forEach((button) => {
    button.addEventListener("click", async () => {
      const engine = engineSelect.value;
      const queryId = button.getAttribute("data-query-id");
      const url = `http://localhost:8000/query/${engine}/${queryId}`;

      // Mostrar mensaje de carga
      timeDisplay.textContent = "Cargando...";
      resultDisplay.textContent = "";

      try {
        const response = await fetch(url);
        if (!response.ok) throw new Error(`Error HTTP: ${response.status}`);
        const data = await response.json();

        timeDisplay.textContent = `${data.time_ms} ms` || "N/A";
        resultDisplay.textContent = JSON.stringify(data.result, null, 2);
      } catch (error) {
        timeDisplay.textContent = "Error";
        resultDisplay.textContent = `Error al obtener datos:\n${error.message}`;
      }
    });
  });
});

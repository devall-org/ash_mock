defmodule AshMock.Info do
  use Spark.InfoGenerator, extension: AshMock, sections: [:mock]
end

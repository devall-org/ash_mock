defmodule AshMock.Info do
  use Spark.InfoGenerator, extension: AshMock, sections: [:shallow_mock]
end

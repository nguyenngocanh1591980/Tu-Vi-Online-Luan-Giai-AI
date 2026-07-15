FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["APIGateway_CS.csproj", "."]
RUN dotnet restore "APIGateway_CS.csproj"

COPY . .
RUN dotnet build "APIGateway_CS.csproj" -c Release -o /app/build

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS publish
WORKDIR /src

COPY --from=build /app/build .
RUN dotnet publish "APIGateway_CS.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=publish /app/publish .

EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD dotnet APIGateway_CS.dll --version || exit 1

ENTRYPOINT ["dotnet", "APIGateway_CS.dll"]

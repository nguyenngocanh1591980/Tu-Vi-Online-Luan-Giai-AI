FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["data_service.csproj", "."]
RUN dotnet restore "data_service.csproj"

COPY . .
RUN dotnet build "data_service.csproj" -c Release -o /app/build

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS publish
WORKDIR /src

COPY --from=build /app/build .
RUN dotnet publish "data_service.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=publish /app/publish .

EXPOSE 5001
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD dotnet data_service.dll --version || exit 1

ENTRYPOINT ["dotnet", "data_service.dll"]

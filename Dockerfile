FROM linuxserver/code-server:latest

ARG LABEL_VERSION="arm64v8"
ARG DOTNET_VERSION="6.0.102"
ARG POWERSHELL_VERSION="7.2.1"

LABEL name="VSCode-Server-DotNet-arm64v8" \
    version=${LABEL_VERSION} \
    description="VSCode Server with .NET Core SDK and PowerShell Pre-Installed for ARM64" \
    maintainer="Vivek Khurana <vkhurana@users.noreply.github.com>"

    # Enable .NET detection of running in a container
    # See: https://github.com/dotnet/dotnet-docker/blob/master/3.0/sdk/bionic/amd64/Dockerfile
ENV DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # No installer frontend interaction
    DEBIAN_FRONTEND=noninteractive \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # SDK version
    DOTNET_SDK_VERSION=${DOTNET_VERSION} \
    # PowerShell version
    POWERSHELL_TOOL_VERSION=${POWERSHELL_VERSION} \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-Ubuntu-20.04-arm64


# apt update and cleanup
# install deps (https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#dependencies)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu66 \
        liblttng-ust0 \
        libssl1.1 \
        libstdc++6 \
        zlib1g \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Install .NET SDK
RUN curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-arm64.tar.gz \
    && mkdir -p /usr/share/dotnet \
    && tar -oxzf dotnet.tar.gz -C /usr/share/dotnet ./packs ./sdk ./sdk-manifests ./templates ./LICENSE.txt ./ThirdPartyNotices.txt \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && dotnet --version

# Install PowerShell global tool
RUN curl -fSL --output PowerShell.Linux.arm64.$POWERSHELL_TOOL_VERSION.nupkg https://pwshtool.blob.core.windows.net/tool/$POWERSHELL_TOOL_VERSION/PowerShell.Linux.arm64.$POWERSHELL_TOOL_VERSION.nupkg \
    && mkdir -p /usr/share/powershell \
    && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $POWERSHELL_TOOL_VERSION PowerShell.Linux.arm64 \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux.arm64.$POWERSHELL_TOOL_VERSION.nupkg \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    && chmod 755 /usr/share/powershell/pwsh \
    # To reduce image size, remove the copy nupkg that nuget keeps.
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm

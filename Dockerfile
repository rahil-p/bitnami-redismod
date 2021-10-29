ARG redis_version="latest"
ARG redisai_version="latest-cpu-x64-bionic"
ARG redisearch_version="latest"
ARG redisgraph_version="latest"
ARG redistimeseries_version="latest"
ARG rejson_version="latest"
ARG rebloom_version="latest"

FROM redislabs/redisai:${redisai_version} AS build_redisai
FROM redislabs/redisearch:${redisearch_version} AS build_redisearch
FROM redislabs/redisgraph:${redisgraph_version} AS build_redisgraph
FROM redislabs/redistimeseries:${redistimeseries_version} AS build_redistimeseries
FROM redislabs/rejson:${rejson_version} AS build_rejson
FROM redislabs/rebloom:${rebloom_version} AS build_rebloom

FROM bitnami/redis:${redis_version} AS redismod

ENV LD_LIBRARY_PATH /usr/lib/redis/modules
ENV REDISGRAPH_DEPS libgomp1

USER root
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ${REDISGRAPH_DEPS}; \
    rm -rf /var/cache/apt
USER 1001

COPY --from=build_redisai ${LD_LIBRARY_PATH}/redisai.so ${LD_LIBRARY_PATH}/
COPY --from=build_redisai ${LD_LIBRARY_PATH}/backends ${LD_LIBRARY_PATH}/backends/
COPY --from=build_redisearch ${LD_LIBRARY_PATH}/redisearch.so ${LD_LIBRARY_PATH}/
COPY --from=build_redisgraph ${LD_LIBRARY_PATH}/redisgraph.so ${LD_LIBRARY_PATH}/
COPY --from=build_redistimeseries ${LD_LIBRARY_PATH}/*.so ${LD_LIBRARY_PATH}/
COPY --from=build_rejson ${LD_LIBRARY_PATH}/*.so ${LD_LIBRARY_PATH}/
COPY --from=build_rebloom ${LD_LIBRARY_PATH}/*.so ${LD_LIBRARY_PATH}/

CMD ["/opt/bitnami/scripts/redis/run.sh", \
    "--loadmodule", "/usr/lib/redis/modules/redisearch.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisgraph.so", \
    "--loadmodule", "/usr/lib/redis/modules/redistimeseries.so", \
    "--loadmodule", "/usr/lib/redis/modules/rejson.so", \
    "--loadmodule", "/usr/lib/redis/modules/redisbloom.so"]

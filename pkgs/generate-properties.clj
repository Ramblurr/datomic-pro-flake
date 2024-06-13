#!/usr/bin/env bb
(require '[babashka.fs :as fs])
(require '[babashka.process :as p])

(defn write-properties [props file-path]
  (with-open [wrtr (io/writer file-path)]
    (doseq [[k v] (sort-by first props)]
      (.write wrtr (str k "=" v "\n")))))

(defn exit-msg [msg]
  (println msg)
  (System/exit 1))

(defn assert-msg
  ;; instead of using (assert) which throws an exception and looks messy, we do this for better DX
  [condition msg]
  (when (not condition)
    (exit-msg (str "Error: " msg))))

(defn read-env-or-file [env-name]
  (let [ef (System/getenv (str env-name "_FILE"))]
    (if (fs/exists? ef)
      (str/trim (slurp ef))
      (System/getenv env-name))))

(def config-opts
  {"host" "DATOMIC_HOST"
   "protocol" "DATOMIC_PROTOCOL"
   "storage-access" "DATOMIC_STORAGE_ACCESS"
   "storage-admin-password" "DATOMIC_STORAGE_ADMIN_PASSWORD"
   "storage-datomic-password" "DATOMIC_STORAGE_DATOMIC_PASSWORD"
   "data-dir" "DATOMIC_DATA_DIR"
   "sql-driver-class" "DATOMIC_SQL_DRIVER_CLASS"
   "pid-file" "DATOMIC_PID_FILE"
   "alt-host" "DATOMIC_ALT_HOST"
   "ping-host" "DATOMIC_HEALTHCHECK_HOST"
   "ping-port" "DATOMIC_HEALTHCHECK_PORT"
   "ping-concurrency" "DATOMIC_HEALTHCHECK_CONCURRENCY"
   "heartbeat-interval-msec" "DATOMIC_HEARTBEAT_INTERVAL_MSEC"
   "encrypt-channel" "DATOMIC_ENCRYPT_CHANNEL"
   "write-concurrency" "DATOMIC_WRITE_CONCURRENCY"
   "read-concurrency" "DATOMIC_READ_CONCURRENCY"
   "port" "DATOMIC_PORT"
   "sql-url" "DATOMIC_SQL_URL"
   "memory-index-threshold" "DATOMIC_MEMORY_INDEX_THRESHOLD"
   "memory-index-max" "DATOMIC_MEMORY_INDEX_MAX"
   "object-cache-max" "DATOMIC_OBJECT_CACHE_MAX"
   "memcached" "DATOMIC_MEMCACHED"
   "memcached-config-timeout-msec" "DATOMIC_MEMCACHED_CONFIG_TIMEOUT_MSEC"
   "memcached-username" "DATOMIC_MEMCACHED_USERNAME"
   "memcached-password" "DATOMIC_MEMCACHED_PASSWORD"
   "memcached-auto-discovery" "DATOMIC_MEMCACHED_AUTO_DISCOVERY"
   "valcache-path" "DATOMIC_VALCACHE_PATH"
   "valcache-max-gb" "DATOMIC_VALCACHE_MAX_GB"})

(def config-defaults {"host" "0.0.0.0"
                      "port" "4334"
                      "storage-access" "remote"
                      "protocol" "dev"
                      "data-dir" "/data"
                      "memory-index-max" "256m"
                      "memory-index-threshold" "32m"
                      "object-cache-max" "128m"})

(def config-sql-defaults {"host" "0.0.0.0"
                          "port" "4334"
                          "sql-driver-class" "org.postgresql.Driver"
                          "memory-index-max" "256m"
                          "memory-index-threshold" "32m"
                          "object-cache-max" "128m"})

(defn get-config [protocol prop env-var]
  (or
   (read-env-or-file env-var)
   (get (condp = protocol "dev"
               config-defaults
               config-sql-defaults) prop)))

(defn load-config []
  (let [protocol (or (read-env-or-file "DATOMIC_PROTOCOL") "dev")]
    (reduce (fn [props [prop env-var]]
              (if-let [val (get-config protocol prop env-var)]
                (assoc props prop val)
                props)) {} config-opts)))

(defn validate-dev-mode [props]
  (assert-msg (contains? props "storage-access") "storage-access is required")
  (if (= "remote" (get props "storage-access"))
    (do
      (assert-msg (contains? props "storage-admin-password") "storage-admin-password is required in dev mode")
      (assert-msg (contains? props "storage-datomic-password") "storage-datomic-password is required in dev mode")
      props)
    (do
      (println "WARNING: Running in dev mode with storage-access != remote.. you won't be able to connect to this transactor outside the container")
      props)))

(defn validate-sql-mode [props]
  (assert-msg (contains? props "sql-url") "sql-url is required")
  props)

(defn validate-config [props]
  (condp = (get props "protocol")
    "dev" (validate-dev-mode props)
    "sql" (validate-sql-mode props)
    props))

(defn get-ip []
  (str/trim (p/shell {:out :string} "hostname -i")))

(defn update-alt-host [props]
  (if (contains? props "alt-host")
    (assoc props "alt-host" (get-ip))
    props))

(defn conf-file []
  (or
   (System/getenv "DATOMIC_TRANSACTOR_PROPERTIES_PATH")
   "/config/transactor.properties"))

(defn format-readme []
  (doseq [[prop env-var] (sort-by first config-opts)]
    (let [default (get config-defaults prop nil)]
      (println (format "* `%s` - `%s`%s" env-var prop (if default (format " (default: %s)"  default) ""))))))

(defn -main [& args]
  #_(format-readme)
  (->
   (load-config)
   (validate-config)
   (update-alt-host)
   (write-properties (conf-file))))

(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))

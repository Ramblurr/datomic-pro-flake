(ns hello
  (:require [datomic.api :as d]))

(def db-uri (let [uri (System/getProperty "datomic.uri")]
              (assert uri "datomic.uri property is nil!")
              uri))

(def schema
  [{:db/ident       :hello/message
    :db/valueType   :db.type/string
    :db/cardinality :db.cardinality/one
    :db/doc         "A hello world message"}

   {:db/ident       :hello/timestamp
    :db/valueType   :db.type/instant
    :db/cardinality :db.cardinality/one
    :db/doc         "When the message was created"}])

(defn create-database [ts]
  (d/create-database db-uri)
  (let [conn (d/connect db-uri)]
    @(d/transact conn schema)
    @(d/transact
      conn
      [{:hello/message   "Hello, Datomic!"
        :hello/timestamp ts}])
    conn))

(defn -main []
  (println "Creating database and schema...")
  (println "My datomic uri is '" db-uri "'")
  (try
    (let [ts      (java.util.Date.)
          conn    (create-database ts)
          db      (d/db conn)
          results (d/q '[:find ?m ?t
                         :where
                         [?e :hello/message ?m]
                         [?e :hello/timestamp ?t]]
                       db)]
      (println "Query results:")
      (doseq [[message timestamp] results]
        (assert (= timestamp ts))
        (println message "at" timestamp))
      (println "Database setup complete!"))
    (finally
      (d/shutdown true))))

